# CPEE-DSTORE

A minimal generic file store for the cloud process execution engine
(cpee.org), built with [riddl](https://github.com/etm/riddl).

It exposes a single generic resource:

```
GET /<uuid>/<name>
PUT /<uuid>/<name>
```

* `uuid` must be a valid UUID (`8-4-4-4-12` hex digits).
* `name` must match `^[a-z_][a-zA-Z0-9_]*$`.

`PUT` accepts a single body parameter of any mimetype and stores it on
disk under the configured data directory as `data/<uuid>/<name>`
(alongside a small sidecar file recording the uploaded mimetype).

`GET` returns the stored content with the mimetype it was uploaded
with. Requests for an unknown `uuid`/`name` pair return `404`;
malformed `uuid`/`name` values return `400`.

## Installation

* gem install cpee-dstore

## Scaffold a local install

* cd ~/run
* cpee-dstore new dstore

## Configuration

The data directory defaults to `data/` next to the server script and
can be overridden either in `dstore.conf`:

```yaml
:data_dir: /home/user/run/store/data
```

or on the command line:

```
./dstore -o data_dir=/home/mangler/Projects/cpee-resources/data -v start
```
