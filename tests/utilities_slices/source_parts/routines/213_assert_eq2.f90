function assert_eq2(n1,n2,string)
character(len=*), intent(in) :: string
integer, intent(in) :: n1,n2
integer :: assert_eq2
if (n1 == n2) then
   assert_eq2=n1
else
   write (*,*) "nrerror: an assert_eq failed with this tag:", string
   stop "program terminated by assert_eq2"
end if
end function assert_eq2
!BL
