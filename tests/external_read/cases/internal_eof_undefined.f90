program p
implicit none
integer::stat
character(40)::text
character(8)::a,b
text='word'
a='old'
b='old'
read(text,*,iostat=stat)a,b
print *,a
end program
