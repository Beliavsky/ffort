module m
contains
subroutine process(x,backup)
character(:),allocatable,intent(inout),optional::x(:,:)
character(*),intent(in),optional::backup
if(present(x)) then
 x=adjustl(x)
 if(present(backup)) x=backup
end if
end subroutine
subroutine forward(x,b)
character(:),allocatable,intent(inout),optional::x(:,:)
character(*),intent(in),optional::b
call process(x,b)
end subroutine
end module
program p
use m
implicit none
character(:),allocatable::x(:,:)
allocate(character(6)::x(2,2))
x=reshape([character(6)::' ab',' c','  de',' f'],[2,2])
call forward()
call forward(x)
print *,len(x),len_trim(x),index(x,'e'),sum(index(x,'a'))
call forward(x,' xy')
print *,len(x),sum(len_trim(x)),sum(index(x,'x'))
end program
