# Configuración mínima de Fish
# Enfoque: ligereza, sin frameworks externos, sin temas pesados

# Silenciar saludo inicial
set -g fish_greeting ''

# Variables de entorno básicas
set -gx EDITOR nano
set -gx PAGER less

# Aliases útiles, manteniendo herramientas presentes en el proyecto
alias ll 'ls -lah'
alias la 'ls -A'
alias grep 'grep --color=auto'
if type -q bat
  alias cat 'bat --style=plain --paging=never'
end

# Integración con yazi si está presente
if type -q yazi
  alias y yazi
end

# Prompt por defecto de fish es suficiente; no añadimos temas