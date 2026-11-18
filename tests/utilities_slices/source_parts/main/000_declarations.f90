program xutil
! 06/16/2019 05:21 AM added code to test .exclude. operator
! added test of above_diag
! driver for procedures in util_mod
use kind_mod, only: dp
use util_mod, only: matrix,vector,if_else,quote,reverse,normalize,frac_true,tail,seq, &
                    above_diag,now,exe_name,and,partition,default_alloc,join_fixed, &
                    write_trim_vec,pos_keep,vec,ends_with,all_equal,check_all_equal, &
                    lag_good_data,intersection,random_matrix,print_matrix_simple, &
                    add_constant_columns,num_matching_char,strip,num_fields,factorial,choose, &
                    num_missing,add_one_var,operator(.exclude.),unique_values,write_words, &
                    concat_char_vec,set_alloc,max_consecutive
implicit none
integer                      :: i,nlag,igroup(5)
integer          , parameter :: n = 4, nobs = 10
real(kind=dp)                :: xvec(n),xvec_check(n),xmat(n,1),xsq(n,n),yvec(n)
character (len=*), parameter :: fmt_cr = "(1x,a20,':',100f8.4)",fmt_a = "(100a10)"
logical                      :: tf(n),ygood(n)
integer          , allocatable :: iuse(:,:),freq(:)
character (len=100) :: xstr
character (len=5)   :: words(5) 
character (len=10), allocatable :: char_vec(:),words_unique(:),xchar(:)
