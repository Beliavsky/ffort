program p
implicit none
character(40)::text
integer::a(2,2),b(1,2,2)
text='1 2 3 4 5 6 7 8'
read(text,*) a,b
if(a(1,1)/=1.or.a(2,1)/=2.or.a(1,2)/=3.or.a(2,2)/=4) stop 1
if(b(1,1,1)/=5.or.b(1,2,1)/=6.or.b(1,1,2)/=7.or.b(1,2,2)/=8) stop 2
print *,1
end program
