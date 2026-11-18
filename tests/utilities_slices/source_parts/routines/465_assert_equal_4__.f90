subroutine assert_equal_4__(n1,n2,n3,n4,name1,name2,name3,name4,procedure)
! print an error message and stop if n1, n2, and n3 are not all equal
integer          , intent(in) :: n1,n2,n3,n4
character (len=*), intent(in) :: procedure               ! name of procedure where assertion is made
character (len=*), intent(in) :: name1,name2,name3,name4 ! variable names 
if (n1 /= n2 .or. n1 /= n3 .or. n1 /= n4) then
   write (*,"(a,4(1x,a),' =',4(1x,i0),a)") "in " // trim(procedure) // ",", &
          trim(name1),trim(name2),trim(name3),trim(name4),n1,n2,n3,n4," must be equal, STOPPING"
   stop
end if
end subroutine assert_equal_4__
!
