elemental function factorial(n) result(ifact)
integer, intent(in) :: n
integer             :: ifact
integer             :: i
ifact = 1
do i=2,n
   ifact = ifact*i
end do
end function factorial
!
