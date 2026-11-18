program main
use original_filter
implicit none
real(dp),allocatable::a(:,:)
allocate(a(4,2))
a=reshape([1d0,2d0,3d0,4d0,10d0,20d0,30d0,40d0],[4,2])
call filter_matrix_rows(a,[1,2],[dim(3d0,1d0),sign(1d0,-1d0)],[4d0,30d0])
write(*,'("filtered:",6(1x,i0))')shape(a),int(a)
write(*,'("combined:",4(1x,i0))')count(parity(a>0d0,dim=1)),radix(a),kind(tiny(a)),int(log_gamma(2d0))
call filter_matrix_rows(a,[1],[100d0],[huge(a)])
write(*,'("removed:",4(1x,i0))')shape(a),count(parity(a>0d0,dim=1)),merge(1,0,parity(a>0d0))
call filter_matrix_rows(a,[1],[tiny(a)],[huge(a)])
write(*,'("repeat:",2(1x,i0))')shape(a)
end program
