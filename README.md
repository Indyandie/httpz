# httpz

A meat and potatos http server written in zsh, using nc (netcat).

## Usage

### Flags

| flag                                   | description           |
| -------------------------------------- | --------------------- |
| `-s` (`--static`),<br> `-h` (`--html`) | Required server type. |
| `-p` `--port`,                         | Optional port number. |

## To Do

- [ ] Separate query string, split parameters
- [ ] Read response
- [ ] file server
  - list files
  - list directories
  - navigate directories
  - server files
- [ ] Use Z shell TCP module
