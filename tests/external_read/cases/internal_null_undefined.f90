program p
implicit none
integer::stat
character(40)::text
character(8)::a
text=','
read(text,*,iostat=stat)a
print *,a
end program
