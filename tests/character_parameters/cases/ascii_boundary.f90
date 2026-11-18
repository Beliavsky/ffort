implicit none
character(*),parameter::a=achar(0),b=char(127)
print *,a==char(0),b==achar(127),kind(a)
end
