program p
implicit none
character(6)::text
integer::a(100),stat
text="100*1"
read(text,*,iostat=stat) a
print *,1
end
