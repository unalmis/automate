Adding files to your `Templates` directory lets you create instances of those
files by right clicking in any directory and selecting `New Document`.

For more info, see
[Gnome Help](https://help.gnome.org/users/gnome-help/stable/files-templates.html.en).

Create soft links of my templates in your `Templates` directory:

```sh
# replace first path with your path to the files
ln -s "${HOME}/Documents/project/automate/template/job.slurm" "${HOME}/Templates/job.slurm"
ln -s "${HOME}/Documents/project/automate/template/LaTeX.tex" "${HOME}/Templates/LaTeX.tex"
ln -s "${HOME}/Documents/project/automate/template/markdown.md" "${HOME}/Templates/markdown.md"
ln -s "${HOME}/Documents/project/automate/template/plain.txt" "${HOME}/Templates/plain.txt"
ln -s "${HOME}/Documents/project/automate/template/python.py" "${HOME}/Templates/python.py"
ln -s "${HOME}/Documents/project/automate/template/shell.sh" "${HOME}/Templates/shell.sh"
```
