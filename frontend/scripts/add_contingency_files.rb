#!/usr/bin/env ruby
# Agrega los archivos de ContingencyCast al target "AcessNet" del proyecto Xcode.
#
# Uso:
#   cd frontend
#   ruby scripts/add_contingency_files.rb
#
# Requiere:  gem install xcodeproj
#
# Idempotente: si los archivos ya están en el proyecto, no los duplica.

require 'xcodeproj'
require 'pathname'

PROJECT_ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(PROJECT_ROOT, 'AcessNet.xcodeproj')
TARGET_NAME = 'AirWay'

# Archivos a agregar (relativos a frontend/).
# Cada entrada: [path_en_disco, grupo_virtual_en_xcode_con_separador_/]
FILES_TO_ADD = [
  ['AcessNet/Core/Models/ContingencyForecast.swift',                       'AcessNet/Core/Models'],
  ['AcessNet/Core/Services/ContingencyService.swift',                      'AcessNet/Core/Services'],
  ['AcessNet/Core/Services/ContingencyExplanationService.swift',           'AcessNet/Core/Services'],
  ['AcessNet/Features/Contingency/Views/ContingencyCastView.swift',        'AcessNet/Features/Contingency/Views'],
  ['AcessNet/Features/Contingency/Components/ProbabilityGauge.swift',      'AcessNet/Features/Contingency/Components'],
  ['AcessNet/Features/Contingency/Components/HorizonCard.swift',           'AcessNet/Features/Contingency/Components'],
  ['AcessNet/Features/Contingency/Components/DriversPanel.swift',          'AcessNet/Features/Contingency/Components'],
  ['AcessNet/Features/Contingency/Components/RecommendationsPanel.swift',  'AcessNet/Features/Contingency/Components'],
].freeze

# ---------------------------------------------------------------------------

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }
abort("✗ Target '#{TARGET_NAME}' no encontrado en el proyecto") unless target

puts "→ Abriendo #{PROJECT_PATH}"
puts "→ Target: #{TARGET_NAME}"
puts ""

# Helper: navega/crea un grupo jerárquico por path
def find_or_create_group(project, path_components)
  current = project.main_group
  path_components.each do |segment|
    found = current.groups.find { |g| g.name == segment || g.display_name == segment || g.path == segment }
    if found
      current = found
    else
      current = current.new_group(segment, segment)
      puts "  + grupo creado: #{segment}"
    end
  end
  current
end

added = 0
skipped = 0

FILES_TO_ADD.each do |disk_relpath, group_path|
  abs_path = File.join(PROJECT_ROOT, disk_relpath)
  unless File.exist?(abs_path)
    puts "✗ No existe en disco: #{disk_relpath}"
    next
  end

  # Ya en el proyecto?
  existing = project.files.find { |f| f.real_path.to_s == abs_path }
  if existing
    # Asegura membership al target
    if target.source_build_phase.files_references.include?(existing)
      puts "✓ ya en proyecto y target: #{disk_relpath}"
      skipped += 1
    else
      target.add_file_references([existing])
      puts "+ agregado al target (ya estaba en proyecto): #{disk_relpath}"
      added += 1
    end
    next
  end

  group = find_or_create_group(project, group_path.split('/'))
  file_ref = group.new_reference(abs_path)
  target.add_file_references([file_ref])

  puts "+ #{disk_relpath}"
  added += 1
end

project.save

puts ""
puts "─" * 50
puts "✓ Agregados: #{added}, ya existentes: #{skipped}"
puts "  Proyecto guardado en: #{PROJECT_PATH}"
puts ""
puts "Siguiente: abre Xcode, Build, y usa ContingencyCastView desde tu TabBar."
