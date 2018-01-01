package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

type route struct {
	Name    string
	Methods []string
	Handle  http.Handler
}

type Handler func(*http.Request) (interface{}, error)

func main() {
	addr := flag.String("a", ":9009", "addr")
	flag.Parse()
	db, err := sql.Open("postgres", flag.Arg(0))
	if err != nil {
		log.Fatalln(err)
	}
	defer db.Close()
	if err := db.Ping(); err != nil {
		log.Fatalln(err)
	}
	r := mux.NewRouter()

	r.Handle("/profiles/", ListProfiles(db)).Methods(http.MethodGet)
	r.Handle("/profiles/", NewProfile(db)).Methods(http.MethodPost)
	r.Handle("/profiles/{id:[a-z]+}", ViewProfile(db)).Methods(http.MethodGet)
	r.Handle("/profiles/{id:[a-z]+}/positions/", AssignPosition(db)).Methods(http.MethodPost).Name("profile.positions.add")
	r.Handle("/profiles/{id:[a-z]+}/positions/{job:[a-z]+}", UnassignPosition(db)).Methods(http.MethodDelete)
	r.Handle("/profiles/{id:[a-z]+}/projects/", AssignProject(db)).Methods(http.MethodPost).Name("profile.projects.add")
	r.Handle("/profiles/{id:[a-z]+}/projects/", UnassignProject(db)).Methods(http.MethodDelete)

	r.Handle("/positions/", ListPositions(db)).Methods(http.MethodGet)
	r.Handle("/positions/", NewPosition(db)).Methods(http.MethodPost)
	r.Handle("/positions/{id:[a-z]+}", ViewPosition(db)).Methods(http.MethodGet)
	r.Handle("/positions/{id:[a-z]+}/profiles/", AssignPosition(db)).Methods(http.MethodPost).Name("position.profiles.add")

	r.Handle("/projects/", ListProjects(db)).Methods(http.MethodGet)
	r.Handle("/projects/", NewProject(db)).Methods(http.MethodPost)
	r.Handle("/projects/{id:[a-z]+}", ViewProject(db)).Methods(http.MethodGet)
	r.Handle("/projects/{id:[a-z]+}/profiles/", AssignProject(db)).Methods(http.MethodPost).Name("project.profiles.add")

	r.Handle("/shifts/", ListShifts(db)).Methods(http.MethodGet)
	r.Handle("/shifts/", AssignShift(db)).Methods(http.MethodPost)

	if err := http.ListenAndServe(*addr, r); err != nil {
		log.Fatalln(err)
	}
}

func negociate(h Handler) http.Handler {
	f := func(w http.ResponseWriter, r *http.Request) {
		data, err := h(r)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		if data == nil {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if err := json.NewEncoder(w).Encode(data); err != nil {
			log.Println(err)
		}
	}
	return http.HandlerFunc(f)
}
