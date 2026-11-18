module m
contains
subroutine inspect(x,label)
character(*),intent(in),optional::x(:,:)
character(*),intent(in),optional::label
if(present(x)) print *,size(x),len(x),sum(len_trim(x)),sum(index(x,'a'))
if(present(label)) print *,len(label),len_trim(label),index(label,'')
end subroutine
end module
program p
use m
implicit none
character(7)::x(0,2)
character(0)::z
call inspect()
call inspect(x,z(:))
end program
