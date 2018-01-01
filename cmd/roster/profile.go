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

type Stat struct {
	Position string `json:"position"`
	Project  string `json:"project"`
	Profile  string `json:"profile"`
	Count    int    `json:"count"`
	Elapsed  int    `json:"elapsed"`
}

type Profile struct {
	Id        int      `json:"id"`
	First     string   `json:"firstname"`
	Last      string   `json:"lastname"`
	Initial   string   `json:"initial"`
	Email     string   `json:"email"`
	Phone     string   `json:"phone"`
	Partner   string   `json:"partner"`
	Positions []string `json:"positions"`
	Stats     []*Stat  `json:"stats,omitempty"`
}

type Position struct {
	Id           int            `json:"id"`
	Name         string         `json:"name"`
	Abbr         string         `json:"abbr"`
	Manager      string         `json:"manager"`
	Assignable   bool           `json:"assignable"`
	Profiles     []string       `json:"profiles,omitempty"`
	Affectations []*Affectation `json:"affectations,omitempty"`
}

type Affectation struct {
	Id       int        `json:"id"`
	Profile  string     `json:"profile"`
	Position string     `json:"position"`
	Ratio    float64    `json:"ratio"`
	Start    *time.Time `json:"dtstart"`
	End      *time.Time `json:"dtend"`
}

func ListProfiles(db *sql.DB) http.Handler {
	const q = `select pk, firstname, lastname, initial, email, phone, positions from vprofiles`
	f := func(r *http.Request) (interface{}, error) {
		switch rs, err := db.Query(q); err {
		case nil:
			defer rs.Close()
			var ps []*Profile
			for rs.Next() {
				u := new(Profile)
				var vs pq.StringArray
				if err := rs.Scan(&u.Id, &u.First, &u.Last, &u.Initial, &u.Email, &u.Phone, &vs); err != nil {
					return nil, err
				}
				u.Positions = []string(vs)
				ps = append(ps, u)
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

func ViewProfile(db *sql.DB) http.Handler {
	const q = `select pk, firstname, lastname, initial, email, phone, positions from vprofiles where initial=$1`
	f := func(r *http.Request) (interface{}, error) {
		var ps pq.StringArray
		u := new(Profile)
		switch err := db.QueryRow(q, mux.Vars(r)["id"]).Scan(&u.Id, &u.First, &u.Last, &u.Initial, &u.Email, &u.Phone, &ps); err {
		case nil:
			u.Positions = []string(ps)
			return u, viewStats(db, u)
		case sql.ErrNoRows:
			return nil, nil
		default:
			return nil, err
		}
	}
	return negociate(f)
}

func viewStats(db *sql.DB, u *Profile) error {
	const q = `select profile, position, project, total, duration from vstats where profile=$1`
	switch rs, err := db.Query(q, u.Initial); err {
	case nil:
		defer rs.Close()
		for rs.Next() {
			s := new(Stat)
			if err := rs.Scan(&s.Profile, &s.Position, &s.Project, &s.Count, &s.Elapsed); err != nil {
				return err
			}
			u.Stats = append(u.Stats, s)
		}
		return nil
	case sql.ErrNoRows:
		return nil
	default:
		return err
	}
}

func NewProfile(db *sql.DB) http.Handler {
	const q = `insert into profiles(firstname, lastname, initial, email, phone) values($1, $2, lower($3), $4, $5) returning pk`
	f := func(r *http.Request) (interface{}, error) {
		defer r.Body.Close()

		p := new(Profile)
		if err := json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(p); err != nil {
			return nil, err
		}
		if err := db.QueryRow(q, p.First, p.Last, p.Initial, p.Email, p.Phone).Scan(&p.Id); err != nil {
			return nil, err
		}
		return p, nil
	}
	return negociate(f)
}

func ListPositions(db *sql.DB) http.Handler {
	const q = `select pk, label, abbr, manager, profiles from vjobs`
	f := func(r *http.Request) (interface{}, error) {
		switch rs, err := db.Query(q); err {
		case nil:
			defer rs.Close()

			var ps []*Position
			for rs.Next() {
				var vs pq.StringArray
				j := new(Position)
				if err := rs.Scan(&j.Id, &j.Name, &j.Abbr, &j.Manager, &vs); err != nil {
					return nil, err
				}
				j.Profiles = []string(vs)
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

func ViewPosition(db *sql.DB) http.Handler {
	const q = `select pk, label, abbr, manager from vjobs where abbr=$1`
	f := func(r *http.Request) (interface{}, error) {
		j := new(Position)
		switch err := db.QueryRow(q, mux.Vars(r)["id"]).Scan(&j.Id, &j.Name, &j.Abbr, &j.Manager); err {
		case nil:
			return j, viewAffectations(db, j)
		case sql.ErrNoRows:
			return nil, err
		default:
			return nil, err
		}
	}
	return negociate(f)
}

func viewAffectations(db *sql.DB, j *Position) error {
	const q = `select pk, profile, ratio from vpositions where position=$1`
	switch rs, err := db.Query(q, j.Abbr); err {
	case nil:
		defer rs.Close()
		for rs.Next() {
			a := new(Affectation)
			if err := rs.Scan(&a.Id, &a.Profile, &a.Ratio); err != nil {
				return err
			}
			j.Affectations = append(j.Affectations, a)
		}
		return nil
	case sql.ErrNoRows:
		return nil
	default:
		return err
	}
}

func NewPosition(db *sql.DB) http.Handler {
	const q = `
    with m(pk) as
      (select pk from profiles where initial=$3)
    insert into jobs(label, abbr, manager) values($1, $2, (select pk from m)) returning pk`
	f := func(r *http.Request) (interface{}, error) {
		defer r.Body.Close()

		j := new(Position)
		if err := json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(j); err != nil {
			return nil, err
		}
		if err := db.QueryRow(q, j.Name, j.Abbr, j.Manager).Scan(&j.Id); err != nil {
			return nil, err
		}
		return j, nil
	}
	return negociate(f)
}

func AssignPosition(db *sql.DB) http.Handler {
	const q = `insert into vpositions(profile, position, ratio) values ($1, $2, $3)`
	f := func(r *http.Request) (interface{}, error) {
		defer r.Body.Close()

		v := struct {
			Position string  `json:"position"`
			Profile  string  `json:"profile"`
			Ratio    float64 `json:"ratio"`
		}{}

		if err := json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(&v); err != nil {
			return nil, err
		}
		switch id, n := mux.Vars(r)["id"], mux.CurrentRoute(r); n.GetName() {
		case "profile.positions.add":
			v.Profile = id
		case "position.profiles.add":
			v.Position = id
		}
		_, err := db.Exec(q, v.Profile, v.Position, v.Ratio)
		return v, err
	}
	return negociate(f)
}

func UnassignPosition(db *sql.DB) http.Handler {
	const q = `delete from vpositions where profile=$1 and position=$2`
	f := func(r *http.Request) (interface{}, error) {
		tx, err := db.Begin()
		if err != nil {
			return nil, err
		}
		vars := mux.Vars(r)
		if _, err := db.Exec(q, vars["id"], vars["job"]); err != nil {
			tx.Rollback()
			return nil, err
		}
		return nil, tx.Commit()
	}
	return negociate(f)
}

func UnassignProject(db *sql.DB) http.Handler {
	const q = `delete from vassignments where project=$1 and profile=$2 and position=$3`
	f := func(r *http.Request) (interface{}, error) {
		tx, err := db.Begin()
		if err != nil {
			return nil, err
		}
		return nil, tx.Commit()
	}
	return negociate(f)
}
