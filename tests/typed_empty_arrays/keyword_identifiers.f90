program p
implicit none
integer::integer,real,logical
integer::a(3)
integer=1;real=2;logical=3
a=[integer,real,logical]
if(any(a/=[1,2,3])) error stop 1
print *, 'PASS' 
end program
