function [a, b, c, d] = MatchFileName(name, reference)


name = regexprep(name,'(\d+)E','$1MeV ');
name = regexprep(name,'(\d+)X','$1MV ');
name = regexprep(name,'(\d+)FFF','$1MVFFF ');
name = regexprep(name,'(\d+)x(\d+)','$1 x $2');
name = regexprep(name,'(\d+)fs','$1 x $1');

nameparts = strsplit(name, {' ','_','-','.'});
x = 0;
a = 0;
b = 0;
c = 0;
d = 0;
for i = 1:length(reference)
    for j = 1:length(reference{i}.energies)
        for k = 1:length(reference{i}.energies{j}.ssds)
			for l = 1:length(reference{i}.energies{j}.ssds{k}.fields)
				y = 0;
				for m = 1:length(nameparts)
					y = y + sum(strcmpi(nameparts{m}, ...
						horzcat(strsplit(reference{i}...
						.machine), strrep(reference{i}.energies{j}...
						.energy, ' ', ''), strsplit(reference{i}.energies{j}...
						.ssds{k}.ssd), strsplit(reference{i}.energies{j}...
						.ssds{k}.fields{l}))));
				end
				if y > x
					x = y;
					a = i;
					b = j;
					c = k;
					d = l;
				end
			end
        end
    end
end

% Clear temporary variables
clear i j k l m x y;