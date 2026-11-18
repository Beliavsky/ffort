program p
implicit none
doubleprecision::a(2)
a=2.0d0
call bump(a)
call bump(a,3.0d0)
print *,a
contains
subroutine bump(x,delta)
double precision,dimension(:),intent(in out)::x
doubleprecision,intent(in),optional::delta
double precision,save::calls=0.0d0
calls=calls+1.0d0
x=x+calls
if(present(delta))x=x+delta
end subroutine
end program
