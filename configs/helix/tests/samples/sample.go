// Package sample is the parity sample for Go.
package sample

import (
    "errors"
    "fmt"
    "strings"
)

const MaxItems = 10

var ErrEmpty = errors.New("empty input")

// Shape has an area.
type Shape interface {
    Area() float64
}

type Rect struct {
    Width, Height float64
    Label         string `json:"label"`
}

func (r *Rect) Area() float64 {
    return r.Width * r.Height
}

func Summarize(shapes []Shape, verbose bool) (string, error) {
    if len(shapes) == 0 {
        return "", ErrEmpty
    }
    var b strings.Builder
    total := 0.0
    for i, s := range shapes {
        if i >= MaxItems {
            break
        }
        total += s.Area()
    }
    counts := map[string]int{"rect": 1}
    ch := make(chan int, 2)
    go func() {
        defer close(ch)
        ch <- len(counts)
    }()
    select {
    case n := <-ch:
        fmt.Fprintf(&b, "%d shapes, total %.2f\n", n, total)
    default:
        b.WriteString(`raw\nstring`)
    }
    switch {
    case verbose && total > 0:
        fmt.Println("verbose", true, nil)
    }
    return b.String(), nil
}
