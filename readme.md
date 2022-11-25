# Automation with shell programs!

No one wants to do something that could have been automated.
[Shell scripts](https://en.wikipedia.org/wiki/Shell_script) are a great tool to
automate tasks.

Shell languages lack the powerful abstractions of higher level languages such as
`python`, but `sh` programs make up for it with their portability.

All programs in this repository are
[POSIX](https://pubs.opengroup.org/onlinepubs/9699919799/) compliant. Meaning
these programs run on any [shell](https://en.wikipedia.org/wiki/Unix_shell).

## Use

- download __example.sh__
- right click in the directory with __example.sh__ and select `Open in Terminal`
- enter `sh example.sh` in terminal

## About the code

### fission.sh

A terminal program that helps set up and maintain RPM or Debian based systems.

[demo of fission.sh](https://github.com/unalmis/automate/blob/main/demo/fission.webm)

#### How is it helpful? Consider that

- it is laborious to set up systems well
- it takes too long to get a fresh system to a state where you can do stuff
- it drains your attention to remember details
- it requires going down a rabbit hole to properly use `jupyter lab` in `conda`
- it is better for a program to set up your parent's, sister's, or dog's system
- __fission.sh__ makes Linux more appealing to newcomers
- __fission.sh__ improves systems that would otherwise not be
- __fission.sh__ helps avoid _weeks_ of troubleshooting

---

### linearize.sh

[Linearizes](https://qpdf.readthedocs.io/en/stable/cli.html#option-linearize)
PDF files in the current directory, recursively.

Note that linearizing a PDF modifies the original.
I am not liable for unexpected results. Please make backups.

---

### mitosis.sh

The simplest backup program you'll ever need.

- diffs the source and destination to only copy missing or modified files
- removes files not on the source from the destination

---

### pull.sh

Updates all local repositories in the current directory, recursively.

---

### replace.sh

Replaces strings within files in the current directory, recursively.
