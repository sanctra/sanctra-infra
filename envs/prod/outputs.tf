output "artifact_registry_repo" { value = google_artifact_registry_repository.docker_repo.id }
output "bucket_renders"        { value = module.bucket_renders.url }
output "bucket_uploads"        { value = module.bucket_uploads.url }
output "bucket_logs"           { value = module.bucket_logs.url }

output "orchestrator_url" { value = module.run_orchestrator.uri }
output "rag_url"          { value = module.run_rag.uri }

output "asr_instance_template"    { value = module.mig_asr.instance_template }
output "avatar_instance_template" { value = module.mig_avatar.instance_template }

output "vertex_index_id"         { value = google_vertex_ai_index.sanctra.id }
output "vertex_index_endpoint"   { value = google_vertex_ai_index_endpoint.sanctra.id }

output "tts_instance_template" {
  value = module.mig_tts.instance_template
}
