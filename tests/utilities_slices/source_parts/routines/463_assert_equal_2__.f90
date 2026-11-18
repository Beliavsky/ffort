subroutine assert_equal_2__(n1,n2,name1,name2,procedure)
! print an error message and stop if n1 /= n2
integer          , intent(in) :: n1,n2
character (len=*), intent(in) :: procedure   ! name of program unit where assertion is made
character (len=*), intent(in) :: name1,name2 ! variable names 
if (n1 /= n2) then
   write (*,"(a,2(1x,a),' =',2(1x,i0),a)") "in " // trim(procedure) // ",", &
          trim(name1),trim(name2),n1,n2," must be equal, STOPPING"
   stop
end if
end subroutine assert_equal_2__
!
