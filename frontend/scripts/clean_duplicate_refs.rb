#!/usr/bin/env ruby
# Limpia file references duplicadas en el target AirWay del proyecto Xcode.
#
# Ocurre cuando se agrega un archivo al target más de una vez (por corridas
# repetidas del script de adición). No es fatal, pero produce warnings.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../AcessNet.xcodeproj', __dir__)
TARGET_NAME = 'AirWay'

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }
abort("✗ Target '#{TARGET_NAME}' no encontrado") unless target

# 1) Dedupe en el source_build_phase: elimina BuildFile duplicados
build_phase = target.source_build_phase
seen = {}
removed = 0
build_phase.files.to_a.each do |bf|
  ref = bf.file_ref
  next unless ref
  key = ref.real_path.to_s
  if seen[key]
    build_phase.files.delete(bf)
    bf.remove_from_project
    removed += 1
    puts "- dup en build phase: #{ref.real_path.basename}"
  else
    seen[key] = bf
  end
end

# 2) Dedupe file references en el proyecto entero
file_refs_seen = {}
removed_refs = 0
project.files.to_a.each do |ref|
  next unless ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)
  next unless ref.real_path
  key = ref.real_path.to_s
  if file_refs_seen[key]
    # No removemos la primera; removemos duplicados
    parent = ref.parent
    parent.children.delete(ref) if parent
    ref.remove_from_project
    removed_refs += 1
    puts "- dup file ref: #{ref.real_path.basename}"
  else
    file_refs_seen[key] = ref
  end
end

project.save

puts ""
puts "✓ Eliminados #{removed} build files duplicados"
puts "✓ Eliminados #{removed_refs} file references duplicados"
