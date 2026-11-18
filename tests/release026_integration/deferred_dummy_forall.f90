program p
implicit none
character(:),allocatable::a(:)
a=['one','two','six']
call transform(a)
print *,len(a),size(a)
print '(4a4)',a
contains
subroutine transform(x)
character(:),allocatable,intent(inout)::x(:)
integer::i
forall(i=1:floor(3.9)) x(i)=x(ceiling(3.1)-i)
x=[character(4)::x,'more']
forall(i=1:size(x),i/=4) x(i)=trim(x(i))//'!'
end subroutine
end program
