module m
contains
subroutine search(a,b)
character(*),intent(in)::a(:,:)
logical,optional,intent(in)::b(:,:)
print *, scan(a,'a',b)
print *, size(scan(a,'a',b),1),size(scan(a,'a',b),2),sum(scan(a,'a',b))
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
