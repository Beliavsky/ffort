! Synthetic GNU driver. All three support routine bodies remain original bytes.
program main
use original_filter
implicit none
real(dp),allocatable::a(:,:)
allocate(a(4,2))
a(:,1)=[1.0_dp,2.0_dp,3.0_dp,4.0_dp]
a(:,2)=[10.0_dp,20.0_dp,30.0_dp,40.0_dp]
call filter_matrix_rows(a,[1],[2.0_dp],[3.0_dp])
if(any(shape(a)/=[2,2])) error stop 1
if(any(a(:,1)/=[2.0_dp,3.0_dp]).or.any(a(:,2)/=[20.0_dp,30.0_dp])) error stop 2
write(*,'(2("[",2(f5.1),"]"))')a
call filter_matrix_rows(a,[1],[2.0_dp],[3.0_dp])
call filter_matrix_rows(a,[integer::],[real(dp)::],[real(dp)::])
call filter_matrix_rows(a,[0,3],[0.0_dp,0.0_dp],[0.0_dp,0.0_dp])
if(size(a,1)/=2) error stop 3
call filter_matrix_rows(a,[1],[5.0_dp],[6.0_dp])
if(size(a,1)/=0.or.size(a,2)/=2) error stop 4
write(*,'("shape:",2(1x,i0))')shape(a)
end program
