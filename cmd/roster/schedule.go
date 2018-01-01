package main

import (
	"database/sql"
	"encoding/json"
	"io"
	"net/http"
	"time"
)

type Shift struct {
	Id       int       `json:"id"`
	Profile  string    `json:"profile"`
	Location string    `json:"location"`
	Position string    `json:"position"`
	Project  string    `json:"project"`
	Start    time.Time `json:"dtstart"`
	End      time.Time `json:"dtend"`
}

func ListShifts(db *sql.DB) http.Handler {
	const q = `select pk, profile, position, project, location, dtstart, dtend from vshifts`
	f := func(r *http.Request) (interface{}, error) {
		switch rs, err := db.Query(q); err {
		case nil:
			defer rs.Close()

			var vs []*Shift
			for rs.Next() {
				s := new(Shift)
				if err := rs.Scan(&s.Id, &s.Profile, &s.Position, &s.Project, &s.Location, &s.Start, &s.End); err != nil {
					return nil, err
				}
				vs = append(vs, s)
			}
			if len(vs) == 0 {
				return nil, nil
			}
			return vs, nil
		case sql.ErrNoRows:
			return nil, nil
		default:
			return nil, err
		}
	}
	return negociate(f)
}

func AssignShift(db *sql.DB) http.Handler {
	const q = `insert into vshifts(profile, position, project, location, dtstart, dtend) values ($1, $2, $3, $4, $5, $6) returning pk`
	f := func(r *http.Request) (interface{}, error) {
		defer r.Body.Close()

		s := new(Shift)
		if err := json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(s); err != nil {
			return nil, err
		}
		if err := db.QueryRow(q, s.Profile, s.Position, s.Project, s.Location, s.Start, s.End).Scan(&s.Id); err != nil {
			return nil, err
		}
		return s, nil
	}
	return negociate(f)
}
