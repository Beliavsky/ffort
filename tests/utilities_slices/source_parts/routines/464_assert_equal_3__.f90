subroutine assert_equal_3__(n1,n2,n3,name1,name2,name3,procedure)
! print an error message and stop if n1, n2, and n3 are not all equal
integer          , intent(in) :: n1,n2,n3
character (len=*), intent(in) :: procedure         ! name of procedure where assertion is made
character (len=*), intent(in) :: name1,name2,name3 ! variable names 
if (n1 /= n2 .or. n1 /= n3) then
   write (*,"(a,3(1x,a),' =',3(1x,i0),a)") "in " // trim(procedure) // ",", &
          trim(name1),trim(name2),trim(name3),n1,n2,n3," must be equal, STOPPING"
   stop
end if
end subroutine assert_equal_3__
!
