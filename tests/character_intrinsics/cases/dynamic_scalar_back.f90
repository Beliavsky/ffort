module m
contains
subroutine check(s,b)
character(*),intent(in)::s(:,:)
logical,intent(in)::b(:,:)
print *,len_trim(s),index(s,' ',.true.),size(s,1),size(s,2)
end subroutine
end module
program p
use m
character(4)::s(2,2)
s=reshape(['a   ','long',' x  ','ab  '],[2,2])
call check(s,reshape([.false.,.true.,.false.,.true.],[2,2]))
print *,sum(len_trim(s(:,1:0))),size(index(s(:,1:0),'x'))
end program
