module m
contains
subroutine search(a,b)
character(*),intent(in)::a(:,:)
logical,optional,intent(in)::b(:,:)
print *, verify(a,'a',b)
print *, size(verify(a,'a',b),1),size(verify(a,'a',b),2),sum(verify(a,'a',b))
end subroutine
end module
program p
use m
implicit none
character(3)::a(2,2)
a=reshape(['aba','baa','ccc','aaa'],[2,2])
call search(a)
call search(a,reshape([.true.,.false.,.false.,.true.],[2,2]))
call search(a(:,1:0))
end program
