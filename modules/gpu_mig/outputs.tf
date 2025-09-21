output "instance_template" { value = google_compute_instance_template.tmpl.self_link }
output "mig_self_link"     { value = google_compute_region_instance_group_manager.mig.self_link }
