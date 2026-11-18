program p
implicit none
integer::u,stat
character(4)::line
u=27
line='old'
read(u,'(a)',iostat=stat)line
print *,line
end program
