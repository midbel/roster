package main

import (
	"time"
)

type Location struct {
	Id   int    `json:"id"`
	Name string `json:"name"`
}

type Period struct {
	Id    int           `json:"id"`
	Name  string        `json:"name"`
	Start time.Duration `json:"hstart"`
	End   time.Duration `json:"hend"`
}
