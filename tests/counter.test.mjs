import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { runInNewContext } from 'node:vm';

test('counter buttons increase by one and reset to zero', () => {
  const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
  const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
  assert.ok(script, 'page script is present');

  const count = { value: '0' };
  const clicks = {};
  const document = {
    querySelector(selector) {
      if (selector === '#count') return count;
      return { addEventListener(event, handler) { clicks[selector] = handler; } };
    },
  };

  runInNewContext(script, { document });
  clicks['#increase']();
  assert.equal(Number(count.value), 1);
  clicks['#reset']();
  assert.equal(Number(count.value), 0);
});
