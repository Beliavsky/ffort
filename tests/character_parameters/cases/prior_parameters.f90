implicit none
character(*),parameter::a="ab",b=a//a,c=trim(b)//"!"
print '(a)',a,b,c
end
