program p
implicit none
integer::a(3,2)
a=0
call fill(a)
print *,a
contains
subroutine fill(x)
integer,intent(out)::x(:,:)
integer::i
forall(i=1:size(x,2)) x(:,i)=i
end subroutine
end program
