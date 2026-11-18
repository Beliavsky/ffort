program p
implicit none
integer::u,s
character(8)::a,b
u=27
read(u,'(a)',iostat=s)a
if(s/=0)error stop 1
read(u,'(a)',iostat=s)b
if(s/=0)error stop 2
print '(a,1x,a,1x,l1)',trim(a),trim(b),lge(b,a)
end program
