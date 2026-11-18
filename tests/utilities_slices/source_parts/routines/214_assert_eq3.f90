function assert_eq3(n1,n2,n3,string)
character(len=*), intent(in) :: string
integer, intent(in) :: n1,n2,n3
integer :: assert_eq3
if (n1 == n2 .and. n2 == n3) then
   assert_eq3=n1
else
   write (*,*) "nrerror: an assert_eq failed with this tag:", string
   stop "program terminated by assert_eq3"
end if
end function assert_eq3
!BL
