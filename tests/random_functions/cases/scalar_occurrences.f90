program p
implicit none
real(8)::a(8),b(8)
a=[draw(),draw(),draw(),draw(),draw(),draw(),draw(),draw()]
if(all(a==a(1))) error stop 1
b=draw()+draw()
if(any(b/=b(1))) error stop 2
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
end program
