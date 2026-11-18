function default_variable_names(n,base) result(names)
integer, intent(in) :: n
character (len=*), intent(in) :: base
character (len=20)            :: names(n)
integer                       :: i
do i=1,n
   write (names(i),"(a,i0)") base,i
end do
end function default_variable_names
!
