initialise_user_global_params <- function(){
  
  global_params = list()
  
  global_params$feature_raster_files = 'data/hab.map.master.zo1.asc'
  global_params$planning_units_raster = 'data/planning.units.uid_20ha.asc'
  
  global_params$number_of_cores = 'all'
  
  # The number of realizations to run
  global_params$realisation_num = 1
  
  global_params$build_simulated_data = FALSE
  
  global_params$overwrite_site_characteristics = TRUE
  
  global_params$save_simulation_outputs = TRUE
  
  # if a file is supplied set this to false to use values in provided list of probabilities, otherwise set to true for equal probability of site development 
  global_params$overwrite_dev_probability_list = TRUE
  
  # if a file is supplied set this to false to use values in provided list of probabilities, otherwise set to true for equal probability of site offset 
  global_params$overwrite_offset_probability_list = TRUE

  # if a file is supplied set this to false to use values in provided list of dynamics, otherwise set to true for on the fly dynamics calculations
  global_params$overwrite_management_dynamics = TRUE
  # if a file is supplied set this to false to use values in provided list of dynamics, otherwise set to true for on the fly dynamics calculations
  global_params$overwrite_feature_dynamics = TRUE
  # if a file is supplied set this to false to use values in provided raster layer of condition classes, otherwise set to true for on the fly condition class calculations
  global_params$overwrite_condition_classes = TRUE
  global_params$overwrite_site_features = TRUE
  return(global_params)
}


# define feature_layers dynamics by logistic curve

logistic_projection <- function(parcel_vals, min_eco_val, max_eco_val, current_dec_rate, time_vec){
  
  t_sh = -1/current_dec_rate * log( ((parcel_vals - min_eco_val)/(max_eco_val - parcel_vals)))
  
  # define logistic curve given logistic parameter set.
  eco_projected = min_eco_val + (max_eco_val - min_eco_val)/(1 + exp(-current_dec_rate*(time_vec - t_sh)))
  
  return(eco_projected)
}


create_dynamics_set <- function(logistic_params_set, condition_class_bounds, time_vec){
  
  dynamics_set = lapply(seq_along(logistic_params_set), 
                        function(i) lapply(seq_along(logistic_params_set[[i]]),
                                           function(j) lapply(seq_along(logistic_params_set[[i]][[j]]),
                                                              function(k) logistic_projection(parcel_vals = logistic_params_set[[i]][[j]][[k]][1], 
                                                                                              min_eco_val = condition_class_bounds[[i]][[j]][1], 
                                                                                              max_eco_val = condition_class_bounds[[i]][[j]][3], 
                                                                                              current_dec_rate = logistic_params_set[[i]][[j]][[k]][2], 
                                                                                              time_vec = time_vec))))
  dynamics_set = lapply(seq_along(logistic_params_set), 
                        function(i) lapply(seq_along(logistic_params_set[[i]]),
                                           function(j) setNames(dynamics_set[[i]][[j]], c('lower_bound', 'best_estimate', 'upper_bound'))))
  
  return(dynamics_set)
}


initialise_user_simulation_params <- function(){ 
  
  simulation_params = list()
  

  # what subset of features to use in the simulation
  simulation_params$features_to_use_in_simulation = 1
  
  # The total number of layers to use in the offset calcuation (iterating from the start)
  simulation_params$features_to_use_in_offset_calc = 1
  
  simulation_params$features_to_use_in_offset_intervention = 1 
  
  simulation_params$use_offset_metric = FALSE
  
  simulation_params$time_steps = 50
  
  # The maximum number of parcels can be selected to offset a single development
  
  simulation_params$max_offset_parcel_num = 10
  
  # Stops the offset from delivering any further gains once it has acheived the gains required
  simulation_params$limit_offset_restoration = TRUE
  
  # The probability per parcel of it being unregulatedly cleared, every parcel gets set to this number - set to zero to turn off
  simulation_params$unregulated_loss_prob = 0.005
  
  # Exclude parcels with less than this number of elements
  simulation_params$min_site_screen_size = 5
  
  # setting (0-1] ignore parcels with size above this number of elements 
  simulation_params$max_site_screen_size_quantile = 0.99
  
  
  #   c('net_gains', 'restoration_gains', 'avoided_condition_decline', 'avoided_loss',
  #     'protected_condition', 'current_condition', 'restored_condition')
  
  simulation_params$offset_action_params = list(c('net_gains', 'restore'))
  
  # This is the equivalent of offset_calc_type for the dev parcel. Options
  # are: 'current_condition' - losses are calcuated relative to the value of
  # the site at the time of the intervention 
  # 'future_condition' - is the do nothing trjectory of the development site.
  simulation_params$dev_calc_type = 'future_condition'    #'future_condition', 'current_condition' 
  
  # Track accumulated credit from previous exchanges (eithger in current or
  # previous time step) and use them to allow developments to proceed if the
  # credit is large enough. FALSE means ignore any exces credit from offset exchanges
  simulation_params$allow_developments_from_credit = TRUE
  
  # How the development parcels are selected options are 'stochastic' or
  # 'weighted'. Note tha weighted requires an additonal weighting layer. If
  # you are running on your own data you need to specify the weights file in
  # intialise_routines.R  (or put the files in simulation_inputs)
  simulation_params$development_selection_type = 'stochastic'  
  
  # The time horizon in which the offset gains need to equal the devlopment impact
  simulation_params$offset_time_horizon = 30
  
  # Include future legal developments in calculating contribution of avoided
  # losses to the impact of the offset. This increases the impact of the
  # offset (due to future losses that are avoided)
  simulation_params$include_potential_developments_in_offset_calc = list(FALSE)
  
  # Include future unregulated developments in calculating contribution of avoided losses
  # to the impact of the offset. This increases the impact of the
  # offset (due to future losses that are avoided)
  simulation_params$include_unregulated_loss_in_offset_calc = list(FALSE)
  
  # Include unregulated clearing in the calculating the contribution of avoided
  # losses to the impact of the development. 
  simulation_params$include_unregulated_loss_in_dev_calc = simulation_params$include_unregulated_loss_in_offset_calc
  simulation_params$initial_credit = 0
  simulation_params$dev_counterfactual_adjustment = 'as_offset'
  # The development impacts is multiplied by this factor (irrespective of how
  # they were caluclated) and the offset impact then needs to match this
  # multiplied development impact
  simulation_params$offset_multiplier = 1
#   directed_developments = vector('list', simulation_params$time_steps)
#   directed_developments[1:50] = c(21:70)
#   simulation_params$directed_developments = list(directed_developments)
#   # when the interventions are set to take place, in this case force to occur once per year
#  simulation_params$intervention_vec = unlist(lapply(seq_along(directed_developments), function(i) length(directed_developments[[i]])))
  
  simulation_params$intervention_num = 500
  
  # when the interventions are set to take place, in this case force to occur once per year
  simulation_params$intervention_vec = build_stochastic_intervention(time_steps = simulation_params$time_steps, 
                                                                     intervention_start = 1, 
                                                                     intervention_end = simulation_params$time_steps, 
                                                                     intervention_num = simulation_params$intervention_num, 
                                                                     sd = 1)

  return(simulation_params)
  
}


user_transform_function <- function(pool_vals, transform_params){
  scaled_scores <- lapply(seq_along(pool_vals), function(i) transform_params[i]/sum(transform_params)*100.68*(1 - exp(-5*( pool_vals[[i]]/transform_params[i] )^2.5) ))
  BAM_score <- sqrt(Reduce('+', scaled_scores[1:3]) * Reduce('+', scaled_scores[4:5]))
  return(BAM_score)
}



initialise_user_feature_params <- function(){
  
  feature_params = list()
  
  feature_params$background_dynamics_type = 'site_scale'
  feature_params$management_dynamics_type = 'site_scale'
  feature_params$scale_features = FALSE
  
  feature_params$site_sample_type = 'trunc_norm'

  feature_params$dynamics_sample_type = 'by_initial_value' #'by_initial_value' 
  # Sample the restoration rates from a uniform distribution to they vary per parcel and per feature
  feature_params$management_dynamics_sample_type = 'by_distribution'
  
  feature_params$project_by_mean = TRUE
  
  feature_params$management_update_dynamics_by_differential = TRUE
  feature_params$background_update_dynamics_by_differential = TRUE
  
  feature_params$perform_management_dynamics_time_shift = TRUE
  feature_params$perform_background_dynamics_time_shift = FALSE
  
  feature_params$update_offset_dynamics_by_time_shift = TRUE
  
  feature_params$sample_management_dynamics = TRUE
  
  # Sample the background dynamics from a uniform distribution to they vary per site and per feature
  feature_params$sample_background_dynamics = TRUE
  
  feature_params$simulated_time_vec = 0:80
  
  feature_params$condition_class_bounds = list(list(c(0, 0.5, 1)))
  
  mean_decline_rate = -0.02
  mean_restoration_rate = 0.04
  background_logistic_params_set = list(list(list(c(0, mean_decline_rate), c(0.5, mean_decline_rate), c(1, mean_decline_rate))))
  
  management_logistic_params_set = list(list(list(c(0.01, 0.04), c(0.01, 0.05), c(0.01, 0.06))))
  
  feature_params$simulated_time_vec = 0:200
  
  feature_params$background_dynamics_bounds <- create_dynamics_set(background_logistic_params_set, 
                                                    feature_params$condition_class_bounds,
                                                    feature_params$simulated_time_vec)
  
  
  feature_params$management_dynamics_bounds <- create_dynamics_set(management_logistic_params_set, 
                                                    feature_params$condition_class_bounds,
                                                    feature_params$simulated_time_vec)
  
  feature_params$initial_condition_class_bounds = lapply(seq_along(feature_params$background_dynamics_bounds), 
                                                         function(i) lapply(seq_along(feature_params$background_dynamics_bounds[[i]]), 
                                                                            function(j) c(feature_params$background_dynamics_bounds[[i]][[j]]$lower_bound[1], 
                                                                                          feature_params$background_dynamics_bounds[[i]][[j]]$best_estimate[1], 
                                                                                          feature_params$background_dynamics_bounds[[i]][[j]]$upper_bound[1])))
  
  return(feature_params)
}

setup_sub_plots <- function(nx, ny, x_space, y_space){
  par(mfrow = c(ny, nx))
  par(cex = 0.6)
  par(mar = c(x_space, y_space, 1, 0), oma = c(2, 4, 2.5, 0.5))
  
  par(tcl = -0.25)
  par(mgp = c(2, 0.3, 0))
  
}


initialise_user_output_params <- function(){
  output_params = list()
  output_params$output_folder = vector()
  output_params$plot_type = 'impacts' # can be 'outcomes'  or 'impacts' or 'none'
  output_params$realisation_num = 'all' # 'all' or number to plot
  output_params$output_type = 'plot'
  output_params$plot_site = TRUE
  output_params$plot_program = TRUE
  output_params$plot_landscape = TRUE
  output_params$plot_offset_metric = FALSE
  output_params$write_pdf = TRUE
  
  output_params$scenario_vec = 'all' #c(1,4,7,10, 8, 2,3,5,6,9,11,12 ) #1:12
  output_params$plot_subset_type = 'all' #c('offset_action_type') # 'offset_calc_type', 'offset_action_type', offset_time_horizon'
  output_params$plot_subset_param = 'all' #c('maintain') # 'net_gains', 'restore', 15
  output_params$features_to_output = 1
  output_params$print_dev_offset_sites = FALSE
  output_params$sets_to_plot = 1
  output_params$nx = 3 
  output_params$ny = 3
  output_params$site_impact_plot_lims_set = list(rep(list(c(-5e2, 5e2)), 3))
  output_params$program_impact_plot_lims_set = list(rep(list(c(-1e4, 1e4)), 3))
  output_params$landscape_impact_plot_lims_set = list(rep(list(c(-1e5, 1e5)), 3))
  output_params$site_outcome_plot_lims_set = list(rep(list(c(0, 1e3)), 3))
  output_params$program_outcome_plot_lims_set = list(rep(list(c(0, 5e4)), 3))
  output_params$landscape_outcome_plot_lims_set = list(rep(list(c(0, 1e5)), 3))
  
  return(output_params)
}

