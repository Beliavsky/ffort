module util_mod
use kind_mod, only: dp, long_int, i64
implicit none
private
public :: matrix,vector,append_col,prepend_col,cbind,combine_col,combine_mat,tensor, &
          cumul_sum,cumul_sum0,int_tf,itrue,ifalse,diag,diag_matrix,true_pos,true_pos_count, &
          demean,if_else,get_text_int,set_offdiagonal,polynom_value, &
          first_pos_ge,last_pos_le,first_row_all_true,last_row_all_true, &
          set_optional,optional_value,newl,integer_label,integer_labels, &
          present_and_true,conform,select_array,select_tensor_real,runif, &
          istdin,istdout,print_time_elapsed,unique,read_comments,num_matching_char, &
          read_vec_real,read_vec_char,read_vec_int,quote,irange,slice,repeat, &
          trim_append,sgn,open_grid,grid,same_rows,munge,exclude,copy_alloc, &
          in_range,good_pos,operator(.in.),operator(.notin.),vec_exclude,ivec, &
          all_equal,str,operator(+),join,join_quote,join_csv,concat,operator(.plus.),cumul_sum_periodic, &
          periodic_sum,default,copy_alloc_opt,check_included,lag_matrix,lag_matrix_vec, &
          variable_names,assert_eq,iminloc,nrerror,in_row,read_alloc,set_alloc, &
          merge_sub,element,grid_alloc,prepend,combine_vec_mat,combine_mat_tensor, &
          combine_tensors,assert,spread_alloc,reverse,renormalize,print_matrix_row_num, &
          size_optional,size_optional_char_vec,read_vec_alloc,set_optional_alloc,interp_two_points,num_obs_bins, &
          alloc_sub,normalize,merge_alloc,true_pos_alloc,write_xname_yname, &
          write_format,check_equal,check_equal_strings,growing_mean,conform_optional,write_lines, &
          grid_min_max,compare_vec,remove_char,copy_file,write_lines_file,select_match,append_file, &
          vector_to_matrix_alloc,size_optional_logical_vec,piecewise_constant,append,positions,dealloc, &
          num_unique,unique_values,unique_values_positions,upper_case_str,lower_case_str,max_optional, &
          min_optional,label_obs_bins,get_words_alloc,ones,sum_no_overlap,pos_first_nonzero,num_changes, &
          write_tensor,reshape_matrix,combine_matrices,sorted,remove_zero_rows,remove_zero_columns, &
          read_words_line,match,lag_data,skip_lines,short_file_name,base_file_name,unique_positions, &
          remove_duplicate_columns,order_distance,nonzero_columns,match_matrix,write_words,operator(.div.), &
          rbinary,exp_ma,merge_char,realloc,sine_bound,sine_transform,sign_changes,duration, &
          power_transform,round_up,grid_round,ts_transform,str_ratio_diff,str_none,running_sum, &
          zero_small_changes,bands,moving_average,bounded_time_series,last,round_less,positive, &
          piecewise_linear,unique_vec,fill_matrix_by_row,all_columns_equal, &
          print_wall_time_elapsed,uniq,nearest_element,exe_name,single,timestamp,timestring, &
          sech,file_exists,newline,diff,fill_vec,fill_panel,interpolate,rebase_vec,rebase_mat, &
          interpolate_matrix_summarize,match_string,get_var,operator(.notall.), &
          empty_char_vec,pi,lagged,zeros,frac_true,alloc_matrix,random_logical, &
          init_random_seed,default_variable_names,frac_changes,tail,seq, &
          above_diag,now,fill_previous,int_grid,get_data,first_true,last_true, &
          replace_char,unix,threshold_weights,time_elapsed,unix_dir,clip,and,close_file, &
          write_optional,pos_changes,pad_directory_name,first_false,backfill,size_optional_real_vec, &
          combine_str,directory_sep,str_real,str_concat,signed_power,operator(.pow.), &
          clip_transform,half_sine_bound,half_sine_transform,fold_bounds,group_sizes, &
          read_matrix,read_3d,random_number_seed,partition,first,default_alloc,first_pos_positive, &
          floor_10,ceiling_10,exact_match_ascending_int,text_after_char,common_value,join_fixed, &
          union_ascending,get_sub,write_trim_vec,matching_pos,ran_uni,text_in_lines,index_case, &
          print_matching_paragraphs,all_strings_in_lines,search_paragraphs_strings,add_uniform_noise, &
          rename_strings,pos_keep,files_exist,check_tickers_exist,lookup,pos,dividend_adjusted_prices, &
          returns,fill_bad,str_simple,str_log,str_diff,vec,print_comment_lines,alloc_char_vec,ends_with, &
          any_strings_in_lines,moving_average_data,madev,lag_good_data,check_all_equal,intersection, &
          add_constant_columns,random_matrix,print_matrix_simple,strip,num_fields,factorial,choose, &
          few_combinations,gen,gen_comb,choose_func,choose_func_long,factorial_long,write_int, &
          num_missing,moving_average_xlen,add_one_var,lower,operator(.exclude.),match_category, &
          concat_char_vec,assert_equal,assert_less,stop_if_missing,put_random_seed,squared_distances, &
          squared_distances_rows,distances_rows,geometric_series,assert_range,directory_exists,checkdir, &
          print_matrix,elu,elu_smooth,logistic,elu_logistic,x_times_logistic,wall_time_elapsed,missing_pos, &
          missing_pos_in_range,read_strings,maxloc_match,num_lines_string_first_field,alloc_init, &
          num_lines_file,lookup_data,sum_ranges,print_vector,duplicate_columns,read_matrix_alloc,read_matrix_unit, &
          is_positive,print_absolute_threshold_counts,print_threshold_counts,print_prices_large_returns, &
          read_words,filter_matrix_rows,unique_ordered,nearby_pos,init_wall_time,within,max_consecutive, &
          num_good_rows,current_time,filter_vec,mask_vec,assert_positive,c,positions_char_string,split, &
          split_string,demean_col,write_vec,print_labeled_vec,nonzero,indexx_order,indexx,tiny_real, &
          piecewise_sine,piecewise_cubic_unit,piecewise_cubic,piecewise_quintic,piecewise_func, &
          piecewise_func_unit,row_count_changes,changes_positions,set_optional_check_size,bad_real, &
          print_labeled_mat,subset,subset_vec_mat,operator(.posin.),unique_char,assert_zero, &
          bound_positions,capped_sum_abs,capped_sum_abs_rows,capped_sum_abs_col,set_random_seed, &
          complement,set_first_false,read_vec_data,assert_conform,same_shape,assert_le,combos,pow_norm, &
          slice_rows,bound_value,join_suffix,join_csv_suffix,diag_3d,offdiag,print_random_seeds, &
          get_numbers,remove,add_or_remove,get_random_seeds,num_records,set_time,ratios,ratio_diff, &
          weighted_sums,weighted_moving_average_vec,moving_average_vec,spline_power_wgt,compress
interface slice_rows
   module procedure slice_rows_real_mat,slice_rows_int_mat
end interface slice_rows
interface print_matrix_row_num
   module procedure print_matrix_real_row_num,print_matrix_int_row_num
end interface print_matrix_row_num
interface same_shape
   module procedure same_shape_real_real_1d, same_shape_real_real_2d, same_shape_real_real_3d
end interface same_shape
interface read_vec_data
   module procedure read_vec_data_unit
end interface read_vec_data
interface nonzero
   module procedure nonzero_real,nonzero_int
end interface nonzero
interface within
   module procedure int_within,real_within
end interface within
interface unique_ordered
   module procedure unique_ordered_int,unique_ordered_i64
end interface unique_ordered
interface read_strings
   module procedure read_strings_vec
end interface read_strings
interface print_matrix
   module procedure print_matrix_simple
end interface print_matrix
interface assert_equal
   module procedure assert_equal_2,assert_equal_3,assert_equal_4,assert_equal_2__, &
                    assert_equal_3__,assert_equal_4__
end interface assert_equal
interface match_category
   module procedure match_category_string_scalar,match_category_string_vec
end interface match_category
interface lower
   module procedure lower_case_str
end interface lower
interface intersection
   module procedure intersection_char
end interface intersection
interface moving_average_data
   module procedure moving_average_data_full,moving_average_data_good,moving_average_min_obs,moving_average_data_full_matrix, &
                    moving_average_data_good_matrix,moving_average_min_obs_matrix
end interface moving_average_data
interface madev
   module procedure madev_good,madev_good_matrix
end interface madev
interface pos_keep
   module procedure pos_keep_char
end interface pos_keep
interface ran_uni
   module procedure ran_uni_vec
end interface ran_uni
interface matching_pos
   module procedure matching_pos_string
end interface matching_pos
interface match_string
   module procedure match_string_scalar,match_string_vec
end interface match_string
interface operator(.pow.)
   module procedure signed_power
end interface
interface operator (.exclude.)
   module procedure diff_vec_char
end interface
interface interpolate
   module procedure interpolate_vec,interpolate_matrix
end interface interpolate
interface diff
   module procedure diff_vector_real, diff_matrix_real, diff_vector_int
end interface diff
interface single
   module procedure single_integer,single_real
end interface single
interface nearest_element
   module procedure nearest_element_real
end interface nearest_element
interface all_columns_equal
   module procedure all_columns_equal_char
end interface all_columns_equal
interface positive
   module procedure positive_int_vec
end interface positive
interface true_pos
   module procedure true_pos_few, true_pos_func
end interface true_pos
interface last
   module procedure last_real
end interface last
interface append_col
   module procedure append_col_vec_mat_real,append_col_mat_vec_real
end interface append_col
interface ts_transform
   module procedure ts_transform_matrix
end interface ts_transform
interface sign_changes
   module procedure sign_changes_real
end interface sign_changes
interface sum_no_overlap
   module procedure sum_no_overlap_vector,sum_no_overlap_matrix
end interface sum_no_overlap
interface realloc
   module procedure realloc_real,realloc_logical,realloc_integer
end interface realloc
interface match_matrix
   module procedure match_integer_matrix
end interface match_matrix
interface unique_positions
   module procedure unique_positions_int
end interface unique_positions
interface lag_data
   module procedure lag_data_vec,lag_data_matrix
end interface lag_data
interface ones
   module procedure ones_vec
end interface ones
interface max_optional
   module procedure max_optional_int
end interface max_optional
interface min_optional
   module procedure min_optional_int
end interface min_optional
interface unique_values
   module procedure unique_values_char,unique_values_int,unique_values_real
end interface unique_values
interface uniq
   module procedure uniq_int,uniq_char,uniq_real
end interface uniq
interface unique_values_positions
   module procedure unique_values_positions_char
end interface unique_values_positions
interface num_unique
   module procedure num_unique_char
end interface num_unique
interface dealloc
   module procedure dealloc_char_vec,dealloc_real_vec,dealloc_real_matrix,dealloc_real_tensor, &
                    dealloc_logical_vec,dealloc_logical_matrix,dealloc_logical_tensor, &
                    dealloc_int_vec,dealloc_int_matrix,dealloc_int_tensor
end interface dealloc
interface append
   module procedure append_str,append_int
end interface append
interface vector_to_matrix_alloc
   module procedure vector_to_matrix_alloc_real
end interface vector_to_matrix_alloc
interface select_match
   module procedure select_match_vec_char
end interface select_match
interface compare_vec
   module procedure compare_vec_strings
end interface compare_vec
interface merge_alloc
   module procedure merge_alloc_int
end interface merge_alloc
interface set_optional_alloc
   module procedure set_optional_alloc_real,set_optional_alloc_int,set_optional_alloc_character
end interface set_optional_alloc
interface read_vec_alloc
   module procedure read_int_vec_alloc,read_unit_int_vec_alloc,read_unit_real_vec_alloc,read_words_line
end interface read_vec_alloc
interface size_optional
   module procedure size_optional_int_vec
end interface size_optional
interface renormalize
   module procedure renormalize_tensor,renormalize_vec
end interface renormalize
interface reverse
   module procedure reverse_real
end interface reverse
interface spread_alloc
   module procedure spread_alloc_char,spread_alloc_logical
end interface spread_alloc
interface combine_tensors
   module procedure combine_tensors_real
end interface combine_tensors
interface combine_mat_tensor
   module procedure combine_mat_tensor_real
end interface combine_mat_tensor
interface combine_vec_mat
   module procedure combine_vec_mat_real
end interface combine_vec_mat
interface prepend
   module procedure prepend_char
end interface prepend
interface grid_alloc
   module procedure grid_alloc_real,grid_alloc_int
end interface grid_alloc
interface element
   module procedure element_char
end interface element
interface merge_sub
   module procedure merge_sub_character
end interface merge_sub
interface read_alloc
   module procedure read_alloc_char
end interface read_alloc
interface in_row
   module procedure in_row_int
end interface in_row
interface first_pos_ge
   module procedure first_pos_ge_int,first_pos_ge_int_vec,first_pos_ge_real
end interface first_pos_ge
interface last_pos_le
   module procedure last_pos_le_int,last_pos_le_int_vec,last_pos_le_real
end interface last_pos_le
interface assert_eq
   module procedure assert_eq2,assert_eq3,assert_eq4,assert_eqn
end interface assert_eq
interface assert
   module procedure assert_scalar,assert_vec
end interface assert
interface demean
   module procedure demean_vec,demean_mat
end interface demean
interface lag_matrix
   module procedure lag_matrix_vec,lag_matrix_mat
end interface lag_matrix
interface copy_alloc_opt
   module procedure copy_alloc_opt_char_vec
end interface copy_alloc_opt
interface default
   module procedure default_logical,default_integer,default_real,default_character,default_character_nlen
end interface default
interface periodic_sum
   module procedure periodic_sum_vec,periodic_sum_mat
end interface periodic_sum
interface cumul_sum_periodic
   module procedure cumul_sum_periodic_vec,cumul_sum_periodic_matrix
end interface cumul_sum_periodic
interface matrix
   module procedure matrix_from_vec,matrix_reshape,matrix_row_col
end interface matrix
interface cbind
   module procedure combine_col_int,combine_col_real,combine_mat_col_real, &
                    combine_vec_mat_col_real,combine_mat_vec_col_real
end interface cbind
interface combine_col
   module procedure combine_col_int,combine_col_real
end interface combine_col
interface str
   module procedure str_int,str_logical
end interface str
interface all_equal
   module procedure all_equal_vec_real,all_equal_vec_int,all_equal_in_vec
end interface all_equal
interface vec_exclude
   module procedure vec_exclude_int
end interface vec_exclude
interface operator (.in.)
   module procedure int_in_vec,char_in_vec,int_vec_in_vec,char_vec_in_vec
end interface
interface operator (.notall.)
   module procedure notall
end interface
interface operator (.notin.)
   module procedure int_not_in_vec,char_not_in_vec,int_vec_not_in_vec
end interface
interface good_pos
   module procedure good_pos_int,good_pos_char
end interface good_pos
interface in_range
   module procedure in_range_int
end interface in_range
interface copy_alloc
   module procedure copy_alloc_matrix_int,copy_alloc_matrix_real,copy_alloc_vec_char,copy_alloc_vec_int,copy_alloc_vec_real
end interface copy_alloc
interface exclude
   module procedure exclude_vec_int,exclude_vec_real
end interface exclude
interface same_rows
   module procedure same_rows_real
end interface same_rows
interface grid
   module procedure grid_int,grid_real
end interface grid
interface sgn
   module procedure sgn_real
end interface sgn
interface unique
   module procedure unique_int,unique_char,unique_real
end interface unique
interface runif
   module procedure runif_vec
end interface runif
interface set_optional
   module procedure set_optional_real,set_optional_integer,set_optional_logical, &
                    set_optional_character
end interface set_optional
interface select_array
   module procedure select_tensor_real,select_vec_character
end interface select_array
interface set_alloc
   module procedure set_alloc_real_tensor,set_alloc_real_matrix,set_alloc_real_vec,set_alloc_character_vec, &
                    set_alloc_int_vec,set_alloc_character_mat,set_alloc_logical_vec,set_alloc_i64_vec, &
                    set_alloc_logical_matrix,set_alloc_integer_matrix,set_alloc_logical_tensor
end interface set_alloc
interface optional_value
   module procedure optional_value_integer, optional_value_character, optional_value_real, optional_value_logical
end interface optional_value
interface cumul_sum
   module procedure cumul_sum_vec,cumul_sum_mat
end interface cumul_sum
interface cumul_sum0
   module procedure cumul_sum0_vec,cumul_sum0_mat
end interface cumul_sum0
interface if_else
   module procedure if_else_real,if_else_int
end interface if_else
interface polynom_value
   module procedure polynom_value_scalar,polynom_value_vec
end interface polynom_value
interface conform
   module procedure conform_real_1d,conform_real_2d,conform_real_3d,conform_real_2d_3d
end interface conform
interface conform_optional
   module procedure conform_optional_real_1d,conform_optional_real_2d
end interface conform_optional
interface slice
   module procedure slice_int_vec,slice_real_vec
end interface slice
interface repeat
   module procedure repeat_char,repeat_char_vec,repeat_int,repeat_real,repeat_logical, &
                    repeat_real_vec
end interface repeat
interface operator(.plus.)
   module procedure char_plus_char,char_plus_int
end interface operator(.plus.)
interface operator(+)
   module procedure char_plus_char,char_plus_int
end interface operator(+)
interface check_included
   module procedure check_included_vec_int,check_included_vec_char
end interface check_included
interface alloc_sub
   module procedure alloc_sub_vec_real,alloc_sub_vec_int
end interface alloc_sub
interface check_equal
   module procedure check_equal_strings
end interface check_equal
interface growing_mean
   module procedure growing_mean_vec
end interface growing_mean
interface pos_first_nonzero
   module procedure pos_first_nonzero_real_vec
end interface pos_first_nonzero
interface sorted
   module procedure sorted_real
end interface sorted
interface match
   module procedure match_char
end interface match
interface unique_vec
   module procedure unique_vec_int,unique_char_int
end interface unique_vec
interface operator(.div.)
   module procedure matrix_by_vector_real
end interface operator(.div.)
interface alloc_matrix
   module procedure alloc_matrix_real
end interface alloc_matrix
interface random_logical
   module procedure random_logical_vec,random_logical_matrix,random_logical_3d
end interface random_logical
interface tail
   module procedure tail_real,tail_int
end interface tail
interface first
   module procedure first_int,first_real,first_char
end interface first
interface default_alloc
   module procedure default_alloc_char
end interface default_alloc
interface get_sub
   module procedure get_sub_vec_real,get_sub_matrix_real,get_sub_array_3d_real
end interface get_sub
interface lookup
   module procedure lookup_char_scalar,lookup_char_vec,lookup_char_matrix
end interface lookup
interface lag_good_data
   module procedure lag_good_data_vec
end interface lag_good_data
interface assert_range
   module procedure assert_int_range,assert_int_vec_range
end interface assert_range
interface maxloc_match
   module procedure maxloc_match_1,maxloc_match_2
end interface
interface alloc_init
   module procedure alloc_init_real
end interface alloc_init
interface num_changes
   module procedure num_changes_int
end interface num_changes
interface assert_positive
   module procedure assert_positive_int
end interface assert_positive
interface indexx
   module procedure indexx_real,indexx_int
end interface indexx
interface indexx_order
   module procedure indexx_order_real
end interface indexx_order
interface subset
   module procedure subset_char
end interface subset
interface operator (.posin.) ! a .posin. b returns the first position in b that matches a, 0 if no match
   module procedure match_string_scalar,match_string_vec,match_int_scalar,match_int_vec
end interface
! interface read_vec_line
!    module procedure read_vec_line_real
! end interface read_vec_line
integer                :: old_time_
integer(kind=long_int) :: mm(100,100)
integer, allocatable :: comb_mat(:,:)
real(kind=dp)    , parameter :: tiny_real = 1.0d-10, pi = 3.141592653589793238462643_dp, &
                                bad_real = -999.0_dp
integer          , parameter :: itrue = 1, ifalse = 0, istdin = 5, istdout = 6, bad_unit=-1, bad_int = -999
character (len=*), parameter :: newl = achar(10), mod_str = "in util_mod::", &
                                lower_case = "abcdefghijklmnopqrstuvwxyz", &
                                upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",mod_name="util_mod", &
                                newline = char(10),bad_char="???"
character (len=20), parameter :: str_ratio_diff="ratio_diff", str_none="none",str_simple="simple",str_log="log", &
                                 str_diff="diff",str_trans(3)=[str_ratio_diff,str_diff,str_none]
! character (len=6), parameter  :: str_simple = "simple", str_log = "log"
type :: int_grid
   integer :: imin,imax,ih
end type int_grid
contains
