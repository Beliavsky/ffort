program p
implicit none
integer::u,n,s
character(:),allocatable::a,b
u=27
a='    '
read(u,'(a)')a
call move_alloc(from=a,to=b)
read(b,*,iostat=s)n
print '(l1,i3,a,a,a)',allocated(a),n,'[',b,']'
end program
