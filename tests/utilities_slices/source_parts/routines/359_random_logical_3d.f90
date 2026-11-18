function random_logical_3d(n1,n2,n3,prob) result(tf)
! return a logical matrix with each element having probability prob of being true
integer      , intent(in) :: n1,n2,n3
real(kind=dp), intent(in) :: prob
logical                   :: tf(n1,n2,n3)
real(kind=dp)             :: xx(n1,n2,n3)
call random_number(xx)
tf = xx > (1-prob)
end function random_logical_3d
!
