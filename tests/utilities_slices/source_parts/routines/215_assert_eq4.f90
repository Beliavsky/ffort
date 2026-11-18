function assert_eq4(n1,n2,n3,n4,string)
character(len=*), intent(in) :: string
integer, intent(in) :: n1,n2,n3,n4
integer :: assert_eq4
if (n1 == n2 .and. n2 == n3 .and. n3 == n4) then
   assert_eq4=n1
else
   write (*,*) "nrerror: an assert_eq failed with this tag:", string
   stop "program terminated by assert_eq4"
end if
end function assert_eq4
!BL
