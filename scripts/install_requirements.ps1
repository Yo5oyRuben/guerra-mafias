param(
  [string]$Python = '.\.venv\Scripts\python.exe',
  [string]$ReqFile = '.requirements'
)

& $Python -m pip install -r $ReqFile
