package main

import (
	"database/sql"
	"encoding/json"
	"io"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/lib/pq"
)

type Project struct {
	Id          int           `json:"id"`
	Name        string        `json:"name"`
	Manager     string        `json:"manager"`
	Start       *time.Time    `json:"dtstart"`
	End         *time.Time    `json:"dtend"`
	Profiles    []string      `json:"profiles,omitempty"`
	Assignments []*Assignment `json:"assignments,omitempty"`
	Resources   []*Resource   `json:"resources,omitempty"`
}

type Resource struct {
	Position string  `json:"position"`
	Want     int     `json:"expected"`
	Got      float64 `json:"current"`
}

type Assignment struct {
	*Affectation
	Position string `json:"position"`
}

func ListProjects(db *sql.DB) http.Handler {
	const q = `select pk, label, dtstart, dtend, manager from vprojects`
	f := func(r *http.Request) (interface{}, error) {
		switch rs, err := db.Query(q); err {
		case nil:
			defer rs.Close()

			var ps []*Project
			for rs.Next() {
				var fd, td pq.NullTime
				j := new(Project)
				if err := rs.Scan(&j.Id, &j.Name, &fd, &td, &j.Manager); err != nil {
					return nil, err
				}
				if fd.Valid && td.Valid {
					j.Start, j.End = &fd.Time, &td.Time
				}
				ps = append(ps, j)
			}
			if len(ps) == 0 {
				return nil, nil
			}
			return ps, nil
		case sql.ErrNoRows:
			return nil, nil
		default:
			return nil, err
		}
	}
	return negociate(f)
}

func ViewProject(db *sql.DB) http.Handler {
	const q = `select pk, label, dtstart, dtend, manager from vprojects where label=$1`
	f := func(r *http.Request) (interface{}, error) {
		j := new(Project)

		var fd, td pq.NullTime
		if err := db.QueryRow(q, mux.Vars(r)["id"]).Scan(&j.Id, &j.Name, &fd, &td, &j.Manager); err != nil {
			return nil, err
		}
		if fd.Valid && td.Valid {
			j.Start, j.End = &fd.Time, &td.Time
		}
		if err := viewAssignments(db, j); err != nil {
			return nil, err
		}
		if err := viewResources(db, j); err != nil {
			return nil, err
		}
		return j, nil
	}
	return negociate(f)
}

func viewResources(db *sql.DB, j *Project) error {
	const q = `select position, expected, current from vresources where project=$1`
	switch rs, err := db.Query(q, j.Name); err {
	case nil, sql.ErrNoRows:
		defer rs.Close()
		for rs.Next() {
			r := new(Resource)
			if err := rs.Scan(&r.Position, &r.Want, &r.Got); err != nil {
				return err
			}
			j.Resources = append(j.Resources, r)
		}
		return nil
	default:
		return err
	}
}

func viewAssignments(db *sql.DB, j *Project) error {
	const q = `select pk, profile, position, ratio from vassignments where project=$1`
	switch rs, err := db.Query(q, j.Name); err {
	case nil:
		defer rs.Close()

		for rs.Next() {
			a := &Assignment{Affectation: new(Affectation)}
			if err := rs.Scan(&a.Id, &a.Profile, &a.Position, &a.Ratio); err != nil {
				return err
			}
			j.Assignments = append(j.Assignments, a)
		}
		return nil
	case sql.ErrNoRows:
		return nil
	default:
		return err
	}
}

func NewProject(db *sql.DB) http.Handler {
	const q = `
    with m(pk) as
    (select pk from profiles where initial=$4)
    insert into projects(label, dtstart, dtend, manager) values($1, $2, $3, (select pk from m)) returning pk`
	f := func(r *http.Request) (interface{}, error) {
		defer r.Body.Close()

		j := new(Project)
		if err := json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(j); err != nil {
			return nil, err
		}
		return j, db.QueryRow(q, j.Name, j.Start, j.End, j.Manager).Scan(&j.Id)
	}
	return negociate(f)
}

func AssignProject(db *sql.DB) http.Handler {
	const q = `insert into vassignments(profile, position, project, ratio) values($1, $2, $3, $4)`
	f := func(r *http.Request) (interface{}, error) {
		defer r.Body.Close()

		v := struct {
			Profile  string  `json:"profile"`
			Position string  `json:"position"`
			Project  string  `json:"project"`
			Ratio    float64 `json:"ratio"`
		}{}
		if err := json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(&v); err != nil {
			return nil, err
		}
		switch id, n := mux.Vars(r)["id"], mux.CurrentRoute(r); n.GetName() {
		case "profile.projects.add":
			v.Profile = id
		case "project.profiles.add":
			v.Project = id
		}
		_, err := db.Exec(q, v.Profile, v.Position, v.Project, v.Ratio)
		return v, err
	}
	return negociate(f)
}
