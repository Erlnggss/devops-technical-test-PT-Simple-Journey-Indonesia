package main

import "testing"

func TestVersion(t *testing.T) {
	if version == "" {
		t.Errorf("Expected version to be set, got empty string")
	}
}