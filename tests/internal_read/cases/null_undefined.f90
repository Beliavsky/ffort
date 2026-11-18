program p
implicit none
character(10)::text
integer::n,stat
text=','
read(text,*,iostat=stat) n
print *,n
end program
