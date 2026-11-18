program keyword_oracle
implicit none

call transform(count=2,message="test=word")
contains
subroutine transform(message,count)
character(len=*),intent(in) :: message
integer,intent(in) :: count
print *,message,count
end subroutine transform

end program
