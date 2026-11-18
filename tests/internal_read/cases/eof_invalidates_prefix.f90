program p
implicit none
character(20)::text
integer::a(2),stat
text='1'
a=9
read(text,*,iostat=stat) a
print *,a(1)
end program
